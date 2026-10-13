import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the broken GlobalGuestHeader class entirely
start_idx = content.find('\nclass GlobalGuestHeader extends ConsumerStatefulWidget {')
if start_idx != -1:
    end_idx = content.find('\nclass GuestHomeScreen extends ConsumerStatefulWidget {', start_idx)
    if end_idx != -1:
        content = content[:start_idx] + content[end_idx:]

# Put back the missing variables in _GuestHomeScreenState
state_class = 'class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen>\n    with SingleTickerProviderStateMixin {'
if state_class in content:
    replacement = '''class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  ViewMode _viewMode = ViewMode.list;
  int? _activeCategory;

  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  late final AnimationController _pulseCtrl;

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
      if (_viewMode == ViewMode.map &&
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

    if (_viewMode == ViewMode.map) {
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
    final profile = _activeCategory != null
        ? RoomFilterProfile.forRoomType(_kCategories[_activeCategory!].roomType)
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
                  if (_viewMode == ViewMode.map) {
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
    if (_activeCategory == index) {
      _resetCategory();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _activeCategory = index);

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
    setState(() {
      _activeCategory = null;
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
    final newMode = _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;
    setState(() {
      _viewMode = newMode;
    });
    ref
        .read(navCollapseProvider.notifier)
        .set(newMode == ViewMode.map ? 1.0 : 0.0);
  }
'''
    # Replace the existing code up to the _getUserCurrentLocationAndSelect method
    target_idx = content.find('  /// Định vị GPS')
    if target_idx != -1:
        # Find the start of the state class
        class_start = content.find(state_class)
        content = content[:class_start] + replacement + '\n' + content[target_idx:]

# Fix the imports
content = content.replace("import '../../application/guest_header_providers.dart';", "")

# Fix the build method which might have been modified
build_start = content.find('  @override\n  Widget build(BuildContext context) {')
pop_scope_start = content.find('    return PopScope(', build_start)
if pop_scope_start != -1:
    # See if the build method has final _viewMode = ref.watch...
    if 'final _viewMode = ref.watch' in content[build_start:pop_scope_start]:
        # Clean it up
        content = content[:build_start] + '''  @override
  Widget build(BuildContext context) {
    final isFiltered = _activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);

    return PopScope(
      canPop: !isFiltered,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _resetCategory();
      },
      child: Scaffold(
''' + content[content.find('        backgroundColor: AppTheme.kBackgroundLight,', pop_scope_start):]

# Restore the Header into the Stack in build method if it was removed
# Check if _SearchHeader is in the build method
if '_SearchHeader(' not in content[build_start:]:
    # Find the AnimatedSwitcher block and insert the Header block right after it inside the Stack
    anim_switcher_idx = content.find('              child: AnimatedSwitcher(')
    if anim_switcher_idx != -1:
        stack_children_end = content.find('            // ── The Floating Header (Liquid Glass) ──', anim_switcher_idx)
        if stack_children_end == -1:
            # We need to insert the header!
            # Let's find the closing bracket of AnimatedSwitcher
            # This is too hard via regex. I will just replace the entire build method.

            build_method_full = '''  @override
  Widget build(BuildContext context) {
    final isFiltered = _activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);

    return PopScope(
      canPop: !isFiltered,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _resetCategory();
      },
      child: Scaffold(
        backgroundColor: AppTheme.kBackgroundLight,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── The Body ──
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _viewMode == ViewMode.map
                    ? GuestMarketplaceMap(
                        key: const ValueKey('map'),
                        onExitMap: _toggleView,
                      )
                    : RefreshIndicator(
                        key: const ValueKey('list'),
                        color: AppTheme.kBrand,
                        onRefresh: notifier.refresh,
                        child: _buildBody(asyncState, notifier, topPadding),
                      ),
              ),
            ),

            // ── The Floating Header (Liquid Glass) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _SearchHeader(
                ctrl: _searchCtrl,
                searchFocusNode: _searchFocusNode,
                asyncState: asyncState,
                pulseCtrl: _pulseCtrl,
                onSearchTap: _openSearch,
                onFilterTap: _openFilter,
                onChipTap: _applyChip,
                viewMode: _viewMode,
                onToggleView: _toggleView,
                activeCategory: _activeCategory,
                onCategoryTap: _selectCategory,
                onResetCategory: _resetCategory,
                onSubmitted: (v) => _handleMapAddressSearch(v),
              ),
            ),

            // ── Bắt sự kiện chạm ngoài overlay ──
            if ((_viewMode == ViewMode.map && _isSearchingAddress) ||
                (_viewMode == ViewMode.map && _mapSuggestions.isNotEmpty))
              Positioned.fill(
                top: 100 + MediaQuery.of(context).padding.top,
                child: GestureDetector(
                  onTap: () {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _mapSuggestions = [];
                      _isSearchingAddress = false;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

            // ── Address Suggestions Overlay (Map Mode only) ──
            if (_viewMode == ViewMode.map &&
                (_isSearchingAddress || _mapSuggestions.isNotEmpty))
              Positioned(
                top: 88 + MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                child: _buildAddressSuggestionsOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<RoomSearchState> asyncState,
    RoomSearchNotifier notifier,
    double topPadding,
  ) {
    return asyncState.when(
      loading: () => _SkeletonList(topPadding: topPadding),
      error: (err, stack) => _ErrorView(onRetry: notifier.refresh),
      data: (state) {
        if (state.rooms.isEmpty) {
          return const _EmptyView();
        }
        return _RoomList(
          state: state,
          notifier: notifier,
          topPadding: topPadding,
        );
      },
    );
  }
'''
            build_end = content.find('\nclass _SearchHeader', build_start)
            if build_end == -1:
                build_end = len(content)
            
            content = content[:build_start] + build_method_full + content[build_end:]

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
