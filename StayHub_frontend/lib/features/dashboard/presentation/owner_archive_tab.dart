import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class OwnerArchiveTab extends ConsumerWidget {
  const OwnerArchiveTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Lưu trữ & Hồ sơ',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionCategory('NHÂN SỰ & QUYỀN', [
                    _ActionItem(
                      'Nhân viên',
                      CupertinoIcons.group_solid,
                      const Color(0xFF4B5563),
                      const Color(0xFFF3F4F6),
                      () {
                        unawaited(context.push('/staff-management'));
                      },
                      imagePath: 'assets/images/features/staff_dispatch.png',
                    ),
                    _ActionItem(
                      'Phân quyền',
                      CupertinoIcons.shield_lefthalf_fill,
                      AppTheme.kBrand,
                      const Color(0xFFE3F0FF),
                      () {
                        // context.push('/roles');
                      },
                      imagePath: 'assets/images/features/rbac.png',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  _buildActionCategory('HỒ SƠ & LƯU TRỮ', [
                    _ActionItem(
                      'Lưu trữ HĐ',
                      CupertinoIcons.archivebox_fill,
                      const Color(0xFFD97706),
                      const Color(0xFFFEF3C7),
                      () {
                        unawaited(
                          context.push('/contract'),
                        ); // Should go to a contract archive list
                      },
                      imagePath: 'assets/images/features/smart_contract.png',
                    ),
                    _ActionItem(
                      'Mẫu in ấn',
                      CupertinoIcons.doc_text_fill,
                      AppTheme.kSuccess,
                      const Color(0xFFD1FAE5),
                      () {
                        unawaited(context.push('/contract-template-edit'));
                      },
                      imagePath: 'assets/images/features/auto_pdf_gen.png',
                    ),
                    _ActionItem(
                      'Hồ sơ số',
                      CupertinoIcons.folder_solid,
                      AppTheme.kBrand,
                      const Color(0xFFE3F0FF),
                      () {
                        // Documents vault
                      },
                      imagePath: 'assets/images/features/document_vault.png',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  _buildActionCategory('TÀI SẢN & VẬT TƯ', [
                    _ActionItem(
                      'Kho vật tư',
                      CupertinoIcons.cube_box_fill,
                      const Color(0xFF4B5563),
                      const Color(0xFFF3F4F6),
                      () {
                        // Inventory
                      },
                      imagePath:
                          'assets/images/features/inventory_management.png',
                    ),
                    _ActionItem(
                      'Bảo trì',
                      CupertinoIcons.wrench_fill,
                      AppTheme.kWarning,
                      const Color(0xFFFEF3C7),
                      () {
                        // Maintenance logs
                      },
                      imagePath: 'assets/images/features/video_maintenance.png',
                    ),
                  ]),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCategory(String title, List<_ActionItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF298FFF), AppTheme.kBrand],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 3 * 12) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: items.asMap().entries.map((e) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + (e.key * 40)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    child: _QuickActionButton(item: e.value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final String? imagePath;
  _ActionItem(
    this.label,
    this.icon,
    this.iconColor,
    this.bgColor,
    this.onTap, {
    this.imagePath,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _ActionItem item;
  const _QuickActionButton({required this.item});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        unawaited(HapticFeedback.lightImpact());
        unawaited(_animCtrl.forward());
      },
      onTapUp: (_) {
        unawaited(_animCtrl.reverse());
        widget.item.onTap();
      },
      onTapCancel: () => _animCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.item.bgColor,
                    widget.item.bgColor.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.item.iconColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: widget.item.iconColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: widget.item.imagePath == null
                  ? Icon(
                      widget.item.icon,
                      color: widget.item.iconColor == const Color(0xFF111827)
                          ? const Color(0xFF1F2937)
                          : widget.item.iconColor,
                      size: 26,
                    )
                  : Image.asset(
                      widget.item.imagePath!,
                      width: 34,
                      height: 34,
                      filterQuality: FilterQuality.high,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
