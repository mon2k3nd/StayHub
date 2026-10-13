import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/bounce_click.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../contract/application/contract_notifier.dart';
import '../../../auth/application/auth_notifier.dart';

class NewMessageSheet extends ConsumerWidget {
  final Function(int id, String name) onChatSelected;

  const NewMessageSheet({super.key, required this.onChatSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractProvider);
    final userRole = ref.watch(authProvider).value?.role ?? 'GUEST';

    // BUGFIX (Bug 51): trước đây mọi trạng thái không phải AsyncData (kể cả
    // AsyncError) đều hiển thị spinner vô hạn. Tách rõ loading vs error.
    if (contractsAsync.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (contractsAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 40,
                color: AppTheme.kTextSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tải được danh sách liên hệ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                color: AppTheme.kAccentColor,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => ref.invalidate(contractProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final activeContracts =
        contractsAsync.value
            ?.where((c) => c.status == 'ACTIVE' || c.status == 'PENDING')
            .toList() ??
        [];
    final contacts = (userRole == 'OWNER')
        ? (contractsAsync.value ?? [])
        : activeContracts;

    final uniqueContacts = <int, Map<String, dynamic>>{};
    for (var c in contacts) {
      final otherUserId = userRole == 'OWNER' ? c.tenantId : c.ownerId;

      if (!uniqueContacts.containsKey(otherUserId)) {
        uniqueContacts[otherUserId] = {
          'id': otherUserId,
          'name': userRole == 'OWNER'
              ? (c.tenantName ?? "Khách thuê")
              : (c.ownerName ?? "Chủ nhà"),
          'subtitle': userRole == 'OWNER'
              ? 'Phòng ${c.roomName ?? c.roomId}'
              : 'Chủ dãy ${c.branchName ?? ""}',
        };
      }
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.kBackgroundLight.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.kTextMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Tạo tin nhắn mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.kBorderColor),
            Expanded(
              child: uniqueContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: AppTheme.kSurfaceBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.person_3_fill,
                              size: 48,
                              color: AppTheme.kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Không có liên hệ nào',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: uniqueContacts.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = uniqueContacts.values.elementAt(index);
                        return BounceClick(
                          onPressed: () {
                            Navigator.pop(context);
                            // BUGFIX (Bug 119): tránh cast cứng `as int`/`as
                            // String` — nếu giá trị null/khác kiểu sẽ ném
                            // TypeError khi bấm chọn liên hệ. Ép kiểu an toàn.
                            final id = contact['id'];
                            onChatSelected(
                              id is int
                                  ? id
                                  : int.tryParse(id?.toString() ?? '') ?? 0,
                              contact['name']?.toString() ?? '',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.kSurface1Light,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.kSurfaceBlue),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.kBrand.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    gradient: PremiumGradients.skyBrand,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (contact['name']?.toString() ?? '')
                                          .initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        contact['subtitle']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.kTextSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: AppTheme.kTextMuted.withValues(
                                    alpha: 0.3,
                                  ),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
