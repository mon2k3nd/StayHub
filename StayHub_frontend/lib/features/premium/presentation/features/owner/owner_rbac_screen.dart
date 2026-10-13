import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_rbac_notifier.dart';

class OwnerRbacScreen extends ConsumerWidget {
  const OwnerRbacScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rbacProvider);
    final notifier = ref.read(rbacProvider.notifier);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Phân Quyền Nhóm Nhân Viên'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.person_badge_plus),
          onPressed: () {},
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 1000),
                        );
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final role = state.roles[index];
                          return _buildRoleCard(
                            role,
                            state.availablePermissions,
                            notifier,
                          );
                        }, childCount: state.roles.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    StaffRole role,
    List<String> availablePermissions,
    RbacNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassContainer(
        borderRadius: 24,
        blur: 20,
        color: CupertinoColors.white.withValues(alpha: 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.shield_fill,
                        color: AppTheme.kAccentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.roleName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${role.memberCount} thành viên',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis_circle),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              role.description,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: CupertinoColors.systemGrey4),
            ),
            const Text(
              'Phân Quyền Chi Tiết',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availablePermissions.map((perm) {
                final hasPerm = role.permissions.contains(perm);
                return GestureDetector(
                  onTap: () => notifier.togglePermission(role.id, perm),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasPerm
                          ? AppTheme.kAccentColor
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasPerm
                            ? AppTheme.kAccentColor
                            : CupertinoColors.systemGrey4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPerm
                              ? CupertinoIcons.checkmark_alt
                              : CupertinoIcons.clear,
                          size: 14,
                          color: hasPerm
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          perm,
                          style: TextStyle(
                            color: hasPerm
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
