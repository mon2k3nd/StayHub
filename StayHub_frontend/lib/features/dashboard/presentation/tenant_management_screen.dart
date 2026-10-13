import 'dart:async' show unawaited;
import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart'
    show LinearProgressIndicator, ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' as import_services;
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/toast_utils.dart';
import '../../auth/application/auth_notifier.dart';
import '../domain/tenant_contract_model.dart';
import '../../../core/utils/time_utils.dart';

// ─── Provider lấy tất cả khách đang thuê ───
final ownerTenantsProvider =
    FutureProvider.autoDispose<List<TenantContractModel>>((ref) async {
      final user = ref.watch(authProvider).value;
      if (user == null) return [];
      final api = ref.read(apiClientProvider);
      try {
        // Lấy tất cả hợp đồng ACTIVE của chủ nhà
        final res = await api.get('/v1/contracts/owner/${user.id}');
        if (res['success'] != true) return [];
        final raw = res['data'];
        final List data = raw is List ? raw : const [];
        // BUGFIX (data): lọc an toàn — tránh `c.status`/`as Map` ném lỗi khi
        // phần tử không phải Map.
        return data
            .whereType<Map>()
            .where((c) => c['status'] == 'ACTIVE')
            .map(
              (c) => TenantContractModel.fromJson(Map<String, dynamic>.from(c)),
            )
            .toList();
      } catch (e) {
        return [];
      }
    });

class TenantManagementScreen extends ConsumerStatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  ConsumerState<TenantManagementScreen> createState() =>
      _TenantManagementScreenState();
}

class _TenantManagementScreenState
    extends ConsumerState<TenantManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String _searchQuery = '';
  bool _isFabExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients) {
      if (_scrollCtrl.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabExpanded) setState(() => _isFabExpanded = false);
      } else if (_scrollCtrl.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabExpanded) setState(() => _isFabExpanded = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final fmt = NumberFormat('#,###', 'vi_VN');
    return '${fmt.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(ownerTenantsProvider);

    return LiquidGlassScaffold(
      title: 'Khách thuê',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          unawaited(import_services.HapticFeedback.lightImpact());
          ref.invalidate(ownerTenantsProvider);
        },
        child: const Icon(
          CupertinoIcons.refresh_circled_solid,
          color: AppTheme.kBrand,
          size: 26,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: CupertinoTextField(
                    controller: _searchCtrl,
                    placeholder: 'Tìm tên khách, số phòng...',
                    placeholderStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        CupertinoIcons.search,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                    ),
                    decoration: null,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    clearButtonMode: OverlayVisibilityMode.editing,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: tenantsAsync.when(
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(radius: 16),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Lỗi: $e',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          onPressed: () => ref.invalidate(ownerTenantsProvider),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                  data: (contracts) {
                    final filtered = contracts.where((c) {
                      if (_searchQuery.isEmpty) return true;
                      final tenantName = (c.tenantName ?? '').toLowerCase();
                      final roomName = (c.roomName ?? '').toLowerCase();
                      final phone = (c.tenantPhone ?? '').toLowerCase();
                      return tenantName.contains(_searchQuery) ||
                          roomName.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty
                                  ? CupertinoIcons.person_2
                                  : CupertinoIcons.search,
                              size: 72,
                              color: const Color(0xFFD1D5DB),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có khách thuê nào đang hoạt động'
                                  : 'Không tìm thấy kết quả cho "$_searchQuery"',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildTenantCard(filtered[i]),
                    );
                  },
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 24,
            right: 20,
            child: GestureDetector(
              onTap: () {
                unawaited(import_services.HapticFeedback.lightImpact());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điều hướng đang phát triển')));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 56,
                width: _isFabExpanded ? 150 : 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.person_add_solid,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                    if (_isFabExpanded) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Thêm khách',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(TenantContractModel contract) {
    final tenantName = contract.tenantName ?? 'Khách thuê';
    final tenantPhone = contract.tenantPhone ?? '';
    final roomName = contract.roomName ?? 'Phòng';
    final branchName = contract.branchName ?? '';
    final startDate = contract.startDate;
    final endDate = contract.endDate;
    final monthlyRent = contract.rentAmount;
    // ignore: unused_local_variable
    final contractId = contract.id;

    // Tính % thời gian hợp đồng còn lại
    double contractProgress = 0;
    try {
      final start = DateTime.parse(startDate ?? '');
      final end = DateTime.parse(endDate ?? '');
      final now = DateTime.now();
      final total = end.difference(start).inDays;
      final elapsed = now.difference(start).inDays;
      contractProgress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0;
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showTenantDetail(contract),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        LiquidGlassColors.tenantAccent.withValues(alpha: 0.8),
                        const Color(0xFF1A6FD4),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      tenantName.isNotEmpty ? tenantName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenantPhone,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'ĐANG THUÊ',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            // Room info
            Row(
              children: [
                _buildInfoChip(
                  CupertinoIcons.house_fill,
                  roomName,
                  AppTheme.kBrand,
                  'assets/images/features/feat_room.png',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    CupertinoIcons.location_fill,
                    branchName,
                    AppTheme.kBrand,
                    'assets/images/features/multi_property.png',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  CupertinoIcons.time_solid,
                  TimeUtils.calcDuration(startDate),
                  AppTheme.kWarning,
                  'assets/images/features/lease_renewal.png',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  CupertinoIcons.money_dollar_circle_fill,
                  _formatCurrency(monthlyRent),
                  AppTheme.kSuccess,
                  'assets/images/features/auto_rent_collection.png',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contract progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HĐ: ${TimeUtils.formatDate(startDate)} → ${TimeUtils.formatDate(endDate)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${(contractProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.kBrand,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: contractProgress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      contractProgress > 0.9
                          ? CupertinoColors.systemRed
                          : AppTheme.kBrand,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color color, [
    String? imagePath,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) => Icon(icon, size: 12, color: color),
            )
          else
            Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showTenantDetail(TenantContractModel contract) {
    final tenantName = contract.tenantName ?? 'Khách thuê';
    final tenantPhone = contract.tenantPhone ?? 'N/A';
    final tenantEmail = contract.idNumber ?? 'N/A';
    final roomName = contract.roomName ?? 'Phòng';
    final branchName = contract.branchName ?? '';
    final isKycVerified = (contract.idNumber ?? '').isNotEmpty;
    final creditScore = isKycVerified ? 100 : 0;
    final startDate = contract.startDate;
    final endDate = contract.endDate;
    final monthlyRent = contract.rentAmount;
    final depositAmount = contract.depositAmount;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: AppTheme.kBackgroundLight,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LiquidGlassColors.tenantAccent.withValues(alpha: 0.9),
                      const Color(0xFF1A6FD4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          tenantName.isNotEmpty
                              ? tenantName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
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
                            tenantName,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tenantPhone,
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            tenantEmail,
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailSection('Hồ sơ tín nhiệm (Credit Profile)', [
                      _buildDetailRow(
                        CupertinoIcons.checkmark_seal_fill,
                        'Định danh CCCD',
                        isKycVerified ? 'Đã xác thực (eKYC)' : 'Chưa xác thực',
                        valueColor: isKycVerified
                            ? AppTheme.kSuccess
                            : CupertinoColors.systemRed,
                      ),
                      _buildDetailRow(
                        CupertinoIcons.star_circle_fill,
                        'Điểm tín nhiệm',
                        '$creditScore/100',
                        valueColor: AppTheme.kBrand,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Thông tin phòng', [
                      _buildDetailRow(
                        CupertinoIcons.house_fill,
                        'Phòng',
                        roomName,
                      ),
                      _buildDetailRow(
                        CupertinoIcons.building_2_fill,
                        'Dãy trọ',
                        branchName,
                      ),
                      _buildDetailRow(
                        CupertinoIcons.calendar,
                        'Bắt đầu thuê',
                        TimeUtils.formatDate(startDate),
                      ),
                      _buildDetailRow(
                        CupertinoIcons.calendar_badge_minus,
                        'Hết hạn HĐ',
                        TimeUtils.formatDate(endDate),
                      ),
                      _buildDetailRow(
                        CupertinoIcons.time_solid,
                        'Đã ở',
                        TimeUtils.calcDuration(startDate),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Thông tin tài chính', [
                      _buildDetailRow(
                        CupertinoIcons.money_dollar_circle_fill,
                        'Tiền thuê/tháng',
                        _formatCurrency(monthlyRent),
                      ),
                      _buildDetailRow(
                        CupertinoIcons.shield_fill,
                        'Tiền cọc',
                        _formatCurrency(depositAmount),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Action buttons
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showMoveInChecklistSheet(contract);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3369B1FF),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.camera_fill,
                                color: CupertinoColors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Biên bản bàn giao phòng số (Move-in)',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(
                          context.push(
                            '/contract-preview',
                            extra: {'contractId': contract.id},
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.kBrand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: AppTheme.kBrand.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text_fill,
                                color: AppTheme.kBrand,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Xem Hợp đồng điện tử',
                                style: TextStyle(
                                  color: AppTheme.kBrand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showBlacklistDialog(contract);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: CupertinoColors.systemRed.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: CupertinoColors.systemRed,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Báo cáo nợ xấu (Blacklist)',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            'Đóng',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveInChecklistSheet(TenantContractModel contract) {
    showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _MoveInChecklistBottomSheet(contract: contract),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: valueColor ?? AppTheme.kBrand),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlacklistDialog(TenantContractModel contract) {
    final tenantName = contract.tenantName ?? 'Khách thuê';
    final tenantId = contract.id; // Using contract ID as fallback
    final reasonController = TextEditingController();

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Báo cáo nợ xấu'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                Text(
                  'Bạn đang đưa $tenantName vào danh sách đen (Blacklist). Khách thuê này sẽ bị cảnh báo nợ xấu trên toàn hệ thống StayHub.',
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: reasonController,
                  placeholder: 'Lý do (trốn tiền phòng, phá đồ...)',
                  maxLines: 3,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.kTextMuted),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {}, // Giả lập chọn ảnh
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.kTextMuted,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.camera_fill,
                          color: AppTheme.kTextSecondary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đính kèm bằng chứng (Hóa đơn, ảnh)',
                          style: TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  unawaited(import_services.HapticFeedback.heavyImpact());
                  ToastUtils.show(
                    context,
                    'Vui lòng nhập lý do!',
                    isError: true,
                  );
                  return;
                }
                Navigator.pop(ctx);

                try {
                  final api = ref.read(apiClientProvider);
                  final res = await api.post(
                    '/v1/tenants/$tenantId/blacklist',
                    data: {
                      'reason': reasonController.text.trim(),
                      'proofUrl': '',
                    },
                  );

                  if (!mounted) return;

                  if (res['success'] == true) {
                    unawaited(import_services.HapticFeedback.lightImpact());
                    ToastUtils.show(
                      context,
                      'Đã thêm khách thuê vào Blacklist thành công!',
                    );
                    // Refresh the list to reflect new trust score
                    ref.invalidate(ownerTenantsProvider);
                  } else {
                    unawaited(import_services.HapticFeedback.heavyImpact());
                    ToastUtils.show(
                      context,
                      res['message'] ?? 'Có lỗi xảy ra',
                      isError: true,
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  unawaited(import_services.HapticFeedback.heavyImpact());
                  ToastUtils.show(context, 'Lỗi mạng: $e', isError: true);
                }
              },
              child: const Text('Báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Digital Move-in Inspection / Checklist Bottom Sheet
// Biên bản bàn giao phòng số — Chốt chỉ số điện/nước & hiện trạng tài sản
// ─────────────────────────────────────────────────────────────────────────────

class _InspectionItem {
  final String title;
  bool isPassed;
  String note;

  _InspectionItem({
    required this.title,
    this.isPassed = true,
    required this.note,
  });
}

class _HandoverPhotoItem {
  final String title;
  final String timestamp;
  final IconData icon;

  const _HandoverPhotoItem({
    required this.title,
    required this.timestamp,
    required this.icon,
  });
}

class _MoveInChecklistBottomSheet extends StatefulWidget {
  final TenantContractModel contract;

  const _MoveInChecklistBottomSheet({required this.contract});

  @override
  State<_MoveInChecklistBottomSheet> createState() =>
      _MoveInChecklistBottomSheetState();
}

class _MoveInChecklistBottomSheetState
    extends State<_MoveInChecklistBottomSheet> {
  final TextEditingController _electricMeterCtrl = TextEditingController(
    text: '1428',
  );
  final TextEditingController _waterMeterCtrl = TextEditingController(
    text: '39',
  );
  final TextEditingController _noteCtrl = TextEditingController(
    text:
        'Phòng sạch sẽ, bàn giao đủ 2 chìa khóa cơ + 2 thẻ thang máy, thiết bị vận hành tốt.',
  );

  bool _isSigned = false;

  late final List<_InspectionItem> _items = [
    _InspectionItem(
      title: 'Điều hòa Daikin 1.5HP + Điều khiển',
      isPassed: true,
      note: 'Làm lạnh sâu, cánh đảo gió êm, remote đầy đủ pin',
    ),
    _InspectionItem(
      title: 'Bình nóng lạnh Ariston 20L & Aptomat',
      isPassed: true,
      note: 'Nước nóng nhanh, rơ-le chống giật ELCB hoạt động chuẩn',
    ),
    _InspectionItem(
      title: 'Tủ lạnh Inverter & Bếp điện đôi',
      isPassed: true,
      note: 'Làm đá nhanh, đầy đủ khay kính, bếp từ đun sôi tốt',
    ),
    _InspectionItem(
      title: 'Khóa cửa thông minh & Thẻ từ ra vào',
      isPassed: true,
      note: 'Đã reset mã số chủ mới, bàn giao 2 thẻ từ thang máy',
    ),
    _InspectionItem(
      title: 'Tường sơn mới, Trần thạch cao & Sàn gạch',
      isPassed: true,
      note: 'Sơn phẳng đẹp, không nứt nẻ, gạch sàn không trầy xước lớn',
    ),
    _InspectionItem(
      title: 'Giường nệm cao su & Tủ quần áo 3 cánh',
      isPassed: true,
      note: 'Nệm sạch đã bọc ga bảo vệ, ray trượt tủ trơn tru',
    ),
  ];

  final List<_HandoverPhotoItem> _photos = const [
    _HandoverPhotoItem(
      title: 'Đồng hồ điện & nước',
      timestamp: '10:15 • Hôm nay',
      icon: CupertinoIcons.bolt_fill,
    ),
    _HandoverPhotoItem(
      title: 'Góc phòng ngủ & Giường',
      timestamp: '10:16 • Hôm nay',
      icon: CupertinoIcons.bed_double_fill,
    ),
    _HandoverPhotoItem(
      title: 'Khu bếp & Tủ lạnh',
      timestamp: '10:18 • Hôm nay',
      icon: CupertinoIcons.cube_box_fill,
    ),
    _HandoverPhotoItem(
      title: 'Nhà vệ sinh & Thiết bị sứ',
      timestamp: '10:20 • Hôm nay',
      icon: CupertinoIcons.sparkles,
    ),
  ];

  @override
  void dispose() {
    _electricMeterCtrl.dispose();
    _waterMeterCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contract = widget.contract;
    final roomName = contract.roomName ?? 'Phòng đang thuê';
    final branchName = contract.branchName ?? 'StayHub Living';
    final tenantName = contract.tenantName ?? 'Khách thuê';
    final tenantPhone = contract.tenantPhone ?? '---';
    final startDateStr = TimeUtils.formatDate(contract.startDate);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    color: AppTheme.kBrand,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Biên bản bàn giao số',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.kBrand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MOVE-IN 2026',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.kBrand,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Chốt mốc chỉ số & tài sản chống tranh chấp cọc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Color(0xFF94A3B8),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFFE2E8F0)),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // 1. Tóm tắt hợp đồng & căn hộ
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.kBrand.withValues(alpha: 0.2),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F69B1FF),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roomName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  branchName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.kSuccess.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.kSuccess,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Đã kích hoạt HĐ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.kSuccess,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: const Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniInfo(
                            'Khách thuê',
                            tenantName,
                            CupertinoIcons.person_fill,
                          ),
                          _buildMiniInfo(
                            'Số liên lạc',
                            tenantPhone,
                            CupertinoIcons.phone_fill,
                          ),
                          _buildMiniInfo(
                            'Ngày bàn giao',
                            startDateStr,
                            CupertinoIcons.calendar,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Chốt chỉ số công tơ ban đầu (Utility Meters)
                const _SectionHeading(
                  icon: CupertinoIcons.gauge,
                  title: 'Chốt chỉ số công tơ đầu vào',
                  badgeText: 'BẮT BUỘC',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Công tơ Điện
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFEF3C7),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08F59E0B),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.bolt_fill,
                                        color: Color(0xFFD97706),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Điện (kWh)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  '3.800 đ/s',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: _electricMeterCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Text(
                                  'kWh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: AppTheme.kSuccess,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ảnh công tơ: Đã chụp',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.kSuccess,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Đồng hồ Nước
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFBAE6FD),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x080284C7),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.drop_fill,
                                        color: Color(0xFF0284C7),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Nước (m³)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  '25k/m³',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            CupertinoTextField(
                              controller: _waterMeterCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Text(
                                  'm³',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: AppTheme.kSuccess,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ảnh đồng hồ: Đã chụp',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.kSuccess,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Bàn giao chìa khóa & thẻ từ
                const _SectionHeading(
                  icon: CupertinoIcons.lock_shield_fill,
                  title: 'Bàn giao chìa khóa & Thẻ ra vào',
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeyBadge(
                        'Chìa khóa cơ',
                        '2 chìa',
                        CupertinoIcons.lock_fill,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: const Color(0xFFF1F5F9),
                      ),
                      _buildKeyBadge(
                        'Thẻ từ thang máy',
                        '2 thẻ',
                        CupertinoIcons.creditcard_fill,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: const Color(0xFFF1F5F9),
                      ),
                      _buildKeyBadge(
                        'Mật mã cửa chính',
                        'Đã đổi riêng',
                        CupertinoIcons.number_square_fill,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Danh mục kiểm tra thiết bị & nội thất
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeading(
                      icon: CupertinoIcons.list_bullet_indent,
                      title: 'Hiện trạng nội thất & thiết bị',
                    ),
                    Text(
                      '${_items.where((i) => i.isPassed).length}/${_items.length} Tốt',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.kBrand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isLast = index == _items.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.note,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    unawaited(
                                      import_services.HapticFeedback
                                          .selectionClick(),
                                    );
                                    setState(() {
                                      item.isPassed = !item.isPassed;
                                      if (!item.isPassed) {
                                        item.note =
                                            'Có dấu hiệu sử dụng / Đã ghi nhận lưu ý';
                                      } else {
                                        item.note =
                                            'Hoạt động chuẩn, sạch sẽ nguyên vẹn';
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isPassed
                                          ? AppTheme.kSuccess.withValues(
                                              alpha: 0.1,
                                            )
                                          : const Color(
                                              0xFFFEF3C7,
                                            ),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: item.isPassed
                                            ? AppTheme.kSuccess.withValues(
                                                alpha: 0.3,
                                              )
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.isPassed
                                              ? CupertinoIcons.check_mark
                                              : CupertinoIcons
                                                    .exclamationmark_triangle_fill,
                                          size: 12,
                                          color: item.isPassed
                                              ? AppTheme.kSuccess
                                              : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.isPassed ? 'Tốt' : 'Cần lưu ý',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: item.isPassed
                                                ? AppTheme.kSuccess
                                                : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Ảnh chụp hiện trạng gắn watermark số
                const _SectionHeading(
                  icon: CupertinoIcons.camera_viewfinder,
                  title: 'Ảnh chụp hiện trạng có dấu mộc số',
                  badgeText: 'WATERMARK 2026',
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, idx) {
                    final photo = _photos[idx];
                    return Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.kBrand.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  photo.icon,
                                  color: AppTheme.kBrand,
                                  size: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TIMESTAMPED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            photo.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            photo.timestamp,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 6. Ghi chú bổ sung
                const _SectionHeading(
                  icon: CupertinoIcons.doc_plaintext,
                  title: 'Ghi chú bàn giao & Cam kết hai bên',
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),

                const SizedBox(height: 24),

                // 7. Niêm phong số & Action Sign
                if (!_isSigned) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.kBrand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.kBrand.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: AppTheme.kBrand,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Biên bản bàn giao này là căn cứ pháp lý duy nhất để đối chiếu chỉ số công tơ và khấu trừ tiền cọc khi trả phòng.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      unawaited(import_services.HapticFeedback.mediumImpact());
                      setState(() {
                        _isSigned = true;
                      });
                      ToastUtils.show(
                        context,
                        'Đã lập và khóa biên bản bàn giao thành công! Dữ liệu đã niêm phong.',
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3369B1FF),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ký duyệt & Khóa biên bản bàn giao',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Đã ký & Khóa thành công
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.kSuccess.withValues(alpha: 0.1),
                          AppTheme.kBrand.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.kSuccess.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: AppTheme.kSuccess,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'BIÊN BẢN ĐÃ ĐƯỢC NIÊM PHONG SỐ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.kSuccess,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã băm bất biến: #SH-HO-${contract.id}-2026',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Dữ liệu đã được lưu trữ an toàn trong phụ lục Hợp đồng điện tử. Đảm bảo 100% minh bạch khi thanh lý.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Text(
                          'Hoàn tất & Đóng',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyBadge(String title, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.kBrand),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          count,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badgeText;

  const _SectionHeading({
    required this.icon,
    required this.title,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.kBrand),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.kBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText!,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.kBrand,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
