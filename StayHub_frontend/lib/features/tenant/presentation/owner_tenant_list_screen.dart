import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../contract/application/contract_notifier.dart';

class OwnerTenantListScreen extends ConsumerStatefulWidget {
  const OwnerTenantListScreen({super.key});

  @override
  ConsumerState<OwnerTenantListScreen> createState() =>
      _OwnerTenantListScreenState();
}

class _OwnerTenantListScreenState extends ConsumerState<OwnerTenantListScreen> {
  String _searchQuery = '';
  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractProvider);

    return LiquidGlassScaffold(
      title: 'Quản Lý Khách Thuê',
      backgroundColors: AppTheme.kBackgroundLight,
      child: contractsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
        data: (contracts) {
          final activeContracts = contracts
              .where((c) => c.status != 'TERMINATED')
              .toList();

          final tenants = activeContracts.map((c) {
            return {
              'id': c.tenantId,
              'name': c.tenantName ?? 'Khách thuê ${c.tenantId}',
              'phone': 'Chưa cập nhật', // Contract model doesn't have phone
              'roomName': c.roomName ?? 'Phòng ${c.roomId}',
              'branchName': c.branchName ?? '',
              'status': c.daysRemaining < 30 ? 'Sắp hết hạn' : 'Đang thuê',
              'avatar':
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(c.tenantName ?? "T")}&background=random',
            };
          }).toList();

          final filtered = tenants
              .where(
                (t) =>
                    t['name'].toString().toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    t['phone'].toString().contains(_searchQuery),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: CupertinoSearchTextField(
                  placeholder: 'Tìm tên, SĐT...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có khách thuê nào.',
                          style: TextStyle(color: AppTheme.kTextSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildTenantCard(context, filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, Map<String, dynamic> t) {
    Color statusColor;
    switch (t['status']) {
      case 'Đang nợ cước':
        statusColor = CupertinoColors.systemRed;
        break;
      case 'Sắp hết hạn':
        statusColor = CupertinoColors.systemOrange;
        break;
      default:
        statusColor = CupertinoColors.systemGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          // Gradient avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: statusColor == CupertinoColors.systemGreen
                    ? [AppTheme.kSuccess, const Color(0xFF059669)]
                    : statusColor == CupertinoColors.systemRed
                    ? [AppTheme.kError, const Color(0xFFDC2626)]
                    : [AppTheme.kWarning, const Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                // BUGFIX (data): trước đây ép `t['name'] as String` — nếu
                // `name` là null/số (JSON lỗi) thì ném TypeError và cả danh
                // sách khách thuê không render. Coerce an toàn.
                (t['name']?.toString() ?? '').isNotEmpty
                    ? (t['name']?.toString() ?? '')
                          .substring(0, 1)
                          .toUpperCase()
                    : 'T',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t['phone']} • ${t['branchName']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.house_alt,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t['roomName'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  t['status'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push('/contract'),
                minimumSize: const Size(0, 0),
                child: const Icon(
                  CupertinoIcons.chevron_right_circle_fill,
                  color: LiquidGlassColors.ownerAccent,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
