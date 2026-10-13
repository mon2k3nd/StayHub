import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

final adminSaasPlansProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get('/v1/admin/saas/plans');
  if (response['success'] == true) {
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }
  return [];
});

final adminCampaignsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get('/v1/admin/saas/campaigns');
  if (response['success'] == true) {
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }
  return [];
});

class AdminSaasManagementScreen extends ConsumerStatefulWidget {
  const AdminSaasManagementScreen({super.key});

  @override
  ConsumerState<AdminSaasManagementScreen> createState() =>
      _AdminSaasManagementScreenState();
}

class _AdminSaasManagementScreenState
    extends ConsumerState<AdminSaasManagementScreen> {
  int _selectedTab = 0;

  void _showCreatePlanModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final branchesCtrl = TextEditingController(text: '1');
    final roomsCtrl = TextEditingController(text: '10');

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo Gói SaaS Mới',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                CupertinoTextField(
                  controller: nameCtrl,
                  placeholder: 'Tên Gói (VD: PRO, BASIC)',
                  padding: const EdgeInsets.all(16),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: priceCtrl,
                  placeholder: 'Đơn Giá (VNĐ)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: branchesCtrl,
                        placeholder: 'Số Dãy',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoTextField(
                        controller: roomsCtrl,
                        placeholder: 'Số Phòng',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    child: const Text('Lưu Gói'),
                    onPressed: () async {
                      try {
                        final client = ref.read(apiClientProvider);
                        await client.post(
                          '/v1/admin/saas/plans',
                          data: {
                            'name': nameCtrl.text,
                            'price': double.tryParse(priceCtrl.text) ?? 0,
                            'maxBranches': int.tryParse(branchesCtrl.text) ?? 1,
                            'maxRooms': int.tryParse(roomsCtrl.text) ?? 10,
                            'active': true,
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        ref.invalidate(adminSaasPlansProvider);
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateCampaignModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final percentCtrl = TextEditingController();

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo Chiến Dịch Marketing',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                CupertinoTextField(
                  controller: nameCtrl,
                  placeholder: 'Tên Chiến Dịch',
                  padding: const EdgeInsets.all(16),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: codeCtrl,
                  placeholder: 'Mã Giảm Giá (VD: SUMMER50)',
                  padding: const EdgeInsets.all(16),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: percentCtrl,
                  placeholder: 'Phần trăm giảm (VD: 50)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(16),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    child: const Text('Lưu Chiến Dịch'),
                    onPressed: () async {
                      try {
                        final client = ref.read(apiClientProvider);
                        await client.post(
                          '/v1/admin/saas/campaigns',
                          data: {
                            'name': nameCtrl.text,
                            'discountCode': codeCtrl.text,
                            'discountPercent':
                                double.tryParse(percentCtrl.text) ?? 0,
                            'active': true,
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        ref.invalidate(adminCampaignsProvider);
                      } catch (e) {
                        debugPrint('Error: $e');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Quản trị SaaS',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.add_circled,
              color: CupertinoColors.activeBlue,
              size: 28,
            ),
            onPressed: () {
              if (_selectedTab == 0) {
                _showCreatePlanModal(context);
              } else {
                _showCreateCampaignModal(context);
              }
            },
          ),
        ],
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTab,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Gói Dịch vụ'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Chiến dịch Marketing'),
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _selectedTab = v);
                },
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              if (_selectedTab == 0) {
                ref.invalidate(adminSaasPlansProvider);
                try {
                  await ref.read(adminSaasPlansProvider.future);
                } catch (e) {
                  debugPrint('Error: $e');
                }
              } else {
                ref.invalidate(adminCampaignsProvider);
                try {
                  await ref.read(adminCampaignsProvider.future);
                } catch (e) {
                  debugPrint('Error: $e');
                }
              }
            },
          ),
          if (_selectedTab == 0) _buildSaasPlansTab() else _buildCampaignsTab(),
        ],
      ),
    );
  }

  Widget _buildSaasPlansTab() {
    final plansAsync = ref.watch(adminSaasPlansProvider);
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: plansAsync.when(
        data: (plans) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _Plan3DCard(plan: plans[index]);
            }, childCount: plans.length),
          );
        },
        loading: () => const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        error: (e, _) => SliverFillRemaining(child: AppErrorWidget(error: e)),
      ),
    );
  }

  Widget _buildCampaignsTab() {
    final campaignsAsync = ref.watch(adminCampaignsProvider);
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: campaignsAsync.when(
        data: (campaigns) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final campaign = campaigns[index];
              return GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (campaign['active'] == true)
                                ? CupertinoColors.systemGreen.withValues(
                                    alpha: 0.2,
                                  )
                                : CupertinoColors.systemOrange.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (campaign['active'] == true)
                                ? 'ONGOING'
                                : 'PENDING',
                            style: TextStyle(
                              color: (campaign['active'] == true)
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          campaign['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã: ${campaign['discountCode']}',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Giảm: ${campaign['discountPercent']}%',
                          style: const TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: CupertinoColors.activeBlue,
                        onPressed: () {
                          // Gửi Push Notification
                          unawaited(
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Gửi Push Notification'),
                                content: Text(
                                  'Bắn thông báo khuyến mãi mã ${campaign['discountCode']} cho tập khách hàng mục tiêu?',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Hủy'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoDialogAction(
                                    child: const Text('Gửi'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Push KM',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: campaigns.length),
          );
        },
        loading: () => const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        error: (e, _) => SliverFillRemaining(child: AppErrorWidget(error: e)),
      ),
    );
  }
}

class _Plan3DCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _Plan3DCard({required this.plan});

  @override
  State<_Plan3DCard> createState() => _Plan3DCardState();
}

class _Plan3DCardState extends State<_Plan3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
    _isFront = !_isFront;
  }

  Color _getPlanColor() {
    final name = (widget.plan['name'] ?? '').toString().toUpperCase();
    if (name.contains('PRO')) return CupertinoColors.activeBlue;
    if (name.contains('PREMIUM') || name.contains('ENTERPRISE')) {
      return CupertinoColors.activeOrange;
    }
    return CupertinoColors.systemGrey;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value;
            final isFront = angle < pi / 2;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isFront
                  ? _buildFront()
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildBack(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront() {
    final color = _getPlanColor();
    final isActive = widget.plan['active'] == true;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.plan['name'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Icon(CupertinoIcons.cube_box_fill, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.plan['price']} VNĐ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giới hạn: ${widget.plan['maxBranches']} dãy, ${widget.plan['maxRooms']} phòng',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? CupertinoColors.systemGreen.withValues(alpha: 0.2)
                      : CupertinoColors.systemRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'EXPIRED',
                  style: TextStyle(
                    color: isActive
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Chạm để lật & chỉnh sửa cấu hình',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final color = _getPlanColor();
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Thay đổi giới hạn',
            style: TextStyle(
              color: CupertinoColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CupertinoButton(
                color: CupertinoColors.systemRed,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(CupertinoIcons.minus),
                onPressed: () {},
              ),
              Text(
                '${widget.plan['maxRooms']} phòng',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              CupertinoButton(
                color: CupertinoColors.activeGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(CupertinoIcons.add),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            color: color,
            onPressed: () {
              // Show Modal to really edit
              _flip();
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
