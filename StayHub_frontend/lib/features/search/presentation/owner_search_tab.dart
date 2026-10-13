import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../application/search_notifier.dart';
import 'dart:async' show unawaited;

class OwnerSearchTab extends ConsumerStatefulWidget {
  const OwnerSearchTab({super.key});

  @override
  ConsumerState<OwnerSearchTab> createState() => _OwnerSearchTabState();
}

class _OwnerSearchTabState extends ConsumerState<OwnerSearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<String> _recentSearches = [];
  static const String _recentPrefsKey = 'owner_recent_searches';

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecentSearches());
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentPrefsKey) ?? [];
      if (mounted) {
        setState(() => _recentSearches = list);
      }
    } catch (_) {}
  }

  Future<void> _saveSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(_recentSearches);
      list.remove(trimmed);
      list.insert(0, trimmed);
      if (list.length > 8) {
        list.removeRange(8, list.length);
      }
      await prefs.setStringList(_recentPrefsKey, list);
      if (mounted) {
        setState(() => _recentSearches = list);
      }
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = List<String>.from(_recentSearches)..remove(item);
      await prefs.setStringList(_recentPrefsKey, list);
      if (mounted) {
        setState(() => _recentSearches = list);
      }
    } catch (_) {}
  }

  Future<void> _clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentPrefsKey);
      if (mounted) {
        setState(() => _recentSearches = []);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    setState(() => _searchQuery = val);
    ref.read(searchProvider.notifier).search(val);
    if (val.trim().length >= 2) {
      unawaited(_saveSearchQuery(val));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tra Cứu',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Khách thuê, phòng, hợp đồng...',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    ref.read(searchProvider.notifier).search(val);
                  },
                  onSubmitted: (val) {
                    _onSearch(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Tên KH, SĐT, CCCD, Phòng...',
                    hintStyle: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 15,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        CupertinoIcons.search,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              CupertinoIcons.clear_thick_circled,
                              color: CupertinoColors.systemGrey,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              ref.read(searchProvider.notifier).search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search Results or Suggestions
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.kBackgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: _searchQuery.isEmpty
                  ? _buildSuggestions()
                  : _buildSearchResults(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GỢI Ý TÌM KIẾM',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SuggestionChip(
                label: 'Phòng 101',
                icon: CupertinoIcons.house_fill,
                imagePath: 'assets/images/features/feat_room.png',
                onTap: () => _setQuery('Phòng 101'),
              ),
              _SuggestionChip(
                label: 'Phòng 201',
                icon: CupertinoIcons.house_fill,
                imagePath: 'assets/images/features/feat_room.png',
                onTap: () => _setQuery('Phòng 201'),
              ),
              _SuggestionChip(
                label: 'Nguyễn',
                icon: CupertinoIcons.person_solid,
                imagePath: 'assets/images/features/ai_roommate.png',
                onTap: () => _setQuery('Nguyễn'),
              ),
              _SuggestionChip(
                label: 'Trần',
                icon: CupertinoIcons.person_solid,
                imagePath: 'assets/images/features/ai_roommate.png',
                onTap: () => _setQuery('Trần'),
              ),
            ],
          ),

          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TRA CỨU GẦN ĐÂY',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: _clearAllRecentSearches,
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      color: AppTheme.kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map(
              (item) => _RecentSearchItem(
                name: item,
                subtitle: 'Đã tìm gần đây',
                onTap: () => _setQuery(item),
                onDelete: () => _removeRecentSearch(item),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(searchProvider);

    return searchState.when(
      data: (data) {
        if (data == null ||
            (data.tenants.isEmpty && data.roomsAndContracts.isEmpty)) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 56,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không tìm thấy kết quả phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy thử tìm theo tên khách thuê, số điện thoại, số CCCD hoặc tên phòng cụ thể.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.kTextMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            if (data.tenants.isNotEmpty) ...[
              Text(
                'KHÁCH THUÊ (${data.tenants.length})',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              ...data.tenants.map(
                (tenant) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResultCard(
                    title: tenant.name,
                    subtitle:
                        'SĐT: ${tenant.phone}${tenant.roomName != null ? ' • ${tenant.roomName}' : ''}',
                    icon: CupertinoIcons.person_solid,
                    imagePath: 'assets/images/features/ai_roommate.png',
                    iconColor: const Color(0xFF1A6FD4),
                    onTap: () {
                      unawaited(context.push('/tenant-profile/${tenant.id}'));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (data.roomsAndContracts.isNotEmpty) ...[
              Text(
                'PHÒNG & HỢP ĐỒNG (${data.roomsAndContracts.length})',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              ...data.roomsAndContracts.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResultCard(
                    title: room.contractId != null
                        ? 'Hợp đồng ${room.name}'
                        : 'Phòng ${room.name}',
                    subtitle: room.tenantName != null
                        ? 'Người đại diện: ${room.tenantName}'
                        : 'Trạng thái: ${room.status}',
                    icon: CupertinoIcons.doc_text_fill,
                    imagePath: 'assets/images/features/smart_contract.png',
                    iconColor: const Color(0xFF10B981),
                    onTap: () {
                      if (room.contractId != null) {
                        unawaited(
                          context.push('/contract/detail/${room.contractId}'),
                        );
                      } else {
                        unawaited(
                          context.push(
                            '/room-detail',
                            extra: {'roomId': room.id},
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text(
              'Đang tìm kiếm...',
              style: TextStyle(fontSize: 13, color: AppTheme.kTextMuted),
            ),
          ],
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: CupertinoColors.systemRed,
                size: 40,
              ),
              const SizedBox(height: 14),
              const Text(
                'Không thể tải kết quả tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.kTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                onPressed: () {
                  if (_searchQuery.isNotEmpty) {
                    ref.read(searchProvider.notifier).search(_searchQuery);
                  }
                },
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setQuery(String q) {
    _searchCtrl.text = q;
    _onSearch(q);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imagePath;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.kBrand.withValues(alpha: 0.08),
              AppTheme.kBrand.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppTheme.kBrand.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, size: 15, color: AppTheme.kBrand),
              )
            else
              Icon(icon, size: 15, color: AppTheme.kBrand),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.kBrandDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _RecentSearchItem({
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          CupertinoIcons.time,
          color: CupertinoColors.systemGrey,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.kTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.kTextMuted),
        ),
        trailing: onDelete != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  unawaited(HapticFeedback.lightImpact());
                  onDelete!();
                },
                child: const Icon(
                  CupertinoIcons.clear,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : null,
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final Color iconColor;
  final VoidCallback onTap;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imagePath,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.15),
                    iconColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: iconColor, size: 22),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFFD1D5DB),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
