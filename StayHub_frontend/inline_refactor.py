import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add GlobalGuestHeader definition at the top (after imports)
new_header_class = '''
import '../../application/guest_header_providers.dart';

class GlobalGuestHeader extends ConsumerStatefulWidget {
  const GlobalGuestHeader({super.key});

  @override
  ConsumerState<GlobalGuestHeader> createState() => _GlobalGuestHeaderState();
}

class _GlobalGuestHeaderState extends ConsumerState<GlobalGuestHeader>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  late final AnimationController _pulseCtrl;

  // Autocomplete gợi ý địa chỉ trên bản đồ
  List<OsmSuggestion> _mapSuggestions = [];
  bool _isSearchingAddress = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (ref.read(guestViewModeProvider) == ViewMode.map &&
          _searchFocusNode.hasFocus &&
          _searchCtrl.text.trim().isEmpty) {
        setState(() {
          _mapSuggestions = OsmMapService.getQuickLocations();
          _isSearchingAddress = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _pulseCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (q.trim().isEmpty) {
      ref.read(roomSearchProvider.notifier).setKeyword('');
      setState(() {
        _isSearchingAddress = false;
        _mapSuggestions = [];
      });
      return;
    }

    if (ref.read(guestViewModeProvider) == ViewMode.map) {
      setState(() => _isSearchingAddress = true);
      _debounce = Timer(const Duration(milliseconds: 600), () async {
        final results = await OsmMapService.searchAddress(q);
        if (mounted) {
          setState(() {
            _mapSuggestions = results;
            _isSearchingAddress = false;
          });
        }
      });
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(roomSearchProvider.notifier).setKeyword(q.trim());
      });
    }
  }

  Future<void> _handleMapAddressSearch(String q) async {
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchingAddress = false;
      _mapSuggestions = [];
    });
    ref.read(roomSearchProvider.notifier).setKeyword(q.trim());
  }

  Widget _buildAddressSuggestionsOverlay() {
    if (_isSearchingAddress) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.kBackgroundLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kTextPrimary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.kBrand),
        ),
      );
    }
    if (_mapSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kTextPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _mapSuggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppTheme.kBorderColor.withValues(alpha: 0.5),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final sugg = _mapSuggestions[index];
            return BounceClick(
              onPressed: () async {
                setState(() {
                  _searchCtrl.text = sugg.displayName;
                  _mapSuggestions = [];
                });
                _searchFocusNode.unfocus();
                ref.read(roomSearchProvider.notifier).setKeyword(sugg.displayName);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: AppTheme.kBrand,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sugg.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.kTextPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openFilter([String? focusedSection]) async {
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    final activeCategory = ref.read(guestActiveCategoryProvider);
    final profile = activeCategory != null
        ? RoomFilterProfile.forRoomType(_kCategories[activeCategory].roomType)
        : RoomFilterProfile.all;
    final result = await RoomSearchFilterSheet.show(
      context,
      cur,
      profile: profile,
      focusedSection: focusedSection,
    );
    if (result != null) {
      ref.read(roomSearchProvider.notifier).applyFilter(result);
    }
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng tìm kiếm',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: Align(
              alignment: Alignment.topCenter,
              child: _SearchSheet(
                initial: _searchCtrl.text,
                onSearch: (q) async {
                  setState(() => _searchCtrl.text = q);
                  if (ref.read(guestViewModeProvider) == ViewMode.map) {
                    await _handleMapAddressSearch(q);
                  } else {
                    _onSearchChanged(q);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyChip(double max) {
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    final active = cur.maxPrice == max;
    ref
        .read(roomSearchProvider.notifier)
        .applyFilter(
          cur.copyWith(
            minPrice: null,
            maxPrice: active ? null : max,
            clearMinPrice: true,
            clearMaxPrice: active,
          ),
        );
  }

  void _selectCategory(int index) {
    if (ref.read(guestActiveCategoryProvider) == index) {
      _resetCategory();
      return;
    }
    HapticFeedback.selectionClick();
    ref.read(guestActiveCategoryProvider.notifier).state = index;

    final cat = _kCategories[index];
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;

    final profile = RoomFilterProfile.forRoomType(cat.roomType);

    ref
        .read(roomSearchProvider.notifier)
        .applyFilter(
          cur.copyWith(
            roomTypes: cat.roomType == null ? const [] : [cat.roomType!],
            keyword: _searchCtrl.text.trim(),
            clearUsageType: !profile.usageType,
            clearBedrooms: !profile.bedrooms,
            clearBeds: !profile.beds,
            clearBathrooms: !profile.bathrooms,
            clearMaxGuests: !profile.maxGuests,
          ),
        );
  }

  void _resetCategory() {
    HapticFeedback.mediumImpact();
    ref.read(guestActiveCategoryProvider.notifier).state = null;
    setState(() {
      _searchCtrl.clear();
    });
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    ref
        .read(roomSearchProvider.notifier)
        .applyFilter(cur.copyWith(roomTypes: const [], keyword: ''));
  }

  void _toggleView() {
    HapticFeedback.mediumImpact();
    final current = ref.read(guestViewModeProvider);
    final newMode = current == ViewMode.list ? ViewMode.map : ViewMode.list;
    ref.read(guestViewModeProvider.notifier).state = newMode;
    ref
        .read(navCollapseProvider.notifier)
        .set(newMode == ViewMode.map ? 1.0 : 0.0);
  }
'''

# Wait, the build method of GlobalGuestHeader needs to return the exact Stack of the header and overlay!
# We'll extract it from GuestHomeScreen's build.

header_start_comment = content.find('            // ── The Floating Header (Liquid Glass) ──')
header_end_comment = content.find('            // ── Bắt sự kiện chạm ngoài')
next_positioned = content.find('          ],\n        ),\n', header_end_comment)

header_block = content[header_start_comment:next_positioned]
# Need to replace some variables in header_block
header_block = header_block.replace('_viewMode', 'ref.watch(guestViewModeProvider)')
header_block = header_block.replace('activeCategory: _activeCategory', 'activeCategory: ref.watch(guestActiveCategoryProvider)')
header_block = header_block.replace('_activeCategory != null', 'ref.watch(guestActiveCategoryProvider) != null')
header_block = header_block.replace('isFiltered', 'ref.watch(guestActiveCategoryProvider) != null')
header_block = header_block.replace('headerExtent', 'ref.watch(guestHeaderHeightProvider)')

new_header_class += '''
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
''' + header_block + '''
      ],
    );
  }
}
'''

# Now, clean up GuestHomeScreen
new_content = content
new_content = new_content.replace('ViewMode _viewMode = ViewMode.list;', '')
new_content = new_content.replace('int? _activeCategory;', '')

new_content = re.sub(r'  // Autocomplete.*?_isSearchingAddress = false;\n', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  final _searchCtrl = TextEditingController\(\);\n  final _searchFocusNode = FocusNode\(\);\n  Timer\? _debounce;\n  late final AnimationController _pulseCtrl;\n', '', new_content)
new_content = re.sub(r'  @override\n  void initState\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  @override\n  void dispose\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _onSearchChanged\(String q\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  Future<void> _handleMapAddressSearch\(String q\) async \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  Widget _buildAddressSuggestionsOverlay\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  Future<void> _openFilter\(\[String\? focusedSection\]\) async \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _openSearch\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _applyChip\(double max\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _selectCategory\(int index\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _resetCategory\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)
new_content = re.sub(r'  void _toggleView\(\) \{.*?\n  \}', '', new_content, flags=re.DOTALL)

# In build method, remove PopScope and Header
build_start = new_content.find('  @override\n  Widget build(BuildContext context) {')
pop_scope_start = new_content.find('    return PopScope(', build_start)
if pop_scope_start != -1:
    scaffold_start = new_content.find('      child: Scaffold(', pop_scope_start)
    if scaffold_start != -1:
        # We replace from pop_scope_start to scaffold_start with just return Scaffold(
        new_content = new_content[:pop_scope_start] + '    final _viewMode = ref.watch(guestViewModeProvider);\n    final headerExtent = ref.watch(guestHeaderHeightProvider);\n    final topPadding = MediaQuery.of(context).padding.top + headerExtent;\n    return Scaffold(' + new_content[scaffold_start + 22:]

# Remove header_start_comment to next_positioned in new_content
header_start_in_new = new_content.find('            // ── The Floating Header (Liquid Glass) ──')
header_end_in_new = new_content.find('            // ── Bắt sự kiện chạm ngoài')
next_positioned_in_new = new_content.find('          ],\n        ),\n', header_end_in_new)

if header_start_in_new != -1 and next_positioned_in_new != -1:
    new_content = new_content[:header_start_in_new] + new_content[next_positioned_in_new:]

# Insert GlobalGuestHeader at the top
insert_pos = new_content.find('\nclass GuestHomeScreen')
new_content = new_content[:insert_pos] + '\n' + new_header_class + '\n' + new_content[insert_pos:]

# Remove unused variables from build
new_content = re.sub(r'    final isFiltered = .*?;\n', '', new_content)
new_content = re.sub(r'    final headerExtent = .*?;\n', '', new_content) # Wait I just added this above, but I'll add it back later if needed, no, I added it in the replace.
# Actually let's just let it be.

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Success')
