import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Put back the import!
if "import '../../application/guest_header_providers.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/guest_header_providers.dart';")

# Fix _activeCategory
content = content.replace('activeCategory: _activeCategory,', 'activeCategory: activeCategory,')

# Fix topPadding and headerExtent duplication inside build method
# Search for topPadding in the build method and remove any duplicates
# I will just write a regex to replace the duplicate block.
# Actually, I can just use a python script to replace the ENTIRE build method again, carefully!

build_start = content.find('  @override\n  Widget build(BuildContext context) {')
pop_scope_start = content.find('    return PopScope(', build_start)
if pop_scope_start != -1:
    content = content[:build_start] + '''  @override
  Widget build(BuildContext context) {
    final activeCategory = ref.watch(guestActiveCategoryProvider);
    final viewMode = ref.watch(guestViewModeProvider);
    final isFiltered = activeCategory != null;
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

# Find where topPadding and headerExtent are defined twice!
# Because I might have appended Scaffold but kept the old variable definitions inside Scaffold somehow?
# Let's clean up the text.
content = re.sub(r'    final headerExtent = isFiltered \? 160\.0 : 224\.0;\n    final topPadding = MediaQuery\.of\(context\)\.padding\.top \+ headerExtent;\n    final asyncState = ref\.watch\(roomSearchProvider\);\n    final notifier = ref\.read\(roomSearchProvider\.notifier\);\n\n    return PopScope\(\n      canPop: !isFiltered,\n      onPopInvokedWithResult: \(didPop, _\) \{\n        if \(didPop\) return;\n        _resetCategory\(\);\n      \},\n      child: Scaffold\(\n        backgroundColor: AppTheme\.kBackgroundLight,\n        body: Stack\(\n          clipBehavior: Clip\.none,\n          children: \[\n            // ── The Body ──\n            Positioned\.fill\(\n              child: AnimatedSwitcher\(\n                duration: const Duration\(milliseconds: 300\),\n                switchInCurve: Curves\.easeOutCubic,\n                switchOutCurve: Curves\.easeInCubic,\n                transitionBuilder: \(child, animation\) \{\n                  return FadeTransition\(\n                    opacity: animation,\n                    child: SlideTransition\(\n                      position: Tween<Offset>\(\n                        begin: const Offset\(0, 0\.05\),\n                        end: Offset\.zero,\n                      \)\.animate\(animation\),\n                      child: child,\n                    \),\n                  \);\n                \},\n                child: viewMode == ViewMode\.map\n                    \? GuestMarketplaceMap\(\n                        key: const ValueKey\('map'\),\n                        onExitMap: _toggleView,\n                      \)\n                    : RefreshIndicator\(\n                        key: const ValueKey\('list'\),\n                        color: AppTheme\.kBrand,\n                        onRefresh: notifier\.refresh,\n                        child: _buildBody\(asyncState, notifier, topPadding\),\n                      \),\n              \),\n            \),\n\n            // ── The Floating Header \(Liquid Glass\) ──\n            Positioned\(\n              top: 0,\n              left: 0,\n              right: 0,\n              child: _SearchHeader\(\n                ctrl: _searchCtrl,\n                searchFocusNode: _searchFocusNode,\n                asyncState: asyncState,\n                pulseCtrl: _pulseCtrl,\n                onSearchTap: _openSearch,\n                onFilterTap: _openFilter,\n                onChipTap: _applyChip,\n                viewMode: viewMode,\n                onToggleView: _toggleView,\n                activeCategory: activeCategory,\n                onCategoryTap: _selectCategory,\n                onResetCategory: _resetCategory,\n                onSubmitted: \(v\) => _handleMapAddressSearch\(v\),\n              \),\n            \),\n\n            // ── Bắt sự kiện chạm ngoài overlay ──\n            if \(\(viewMode == ViewMode\.map && _isSearchingAddress\) \|\|\n                \(viewMode == ViewMode\.map && _mapSuggestions\.isNotEmpty\)\)\n              Positioned\.fill\(\n                top: 100 \+ MediaQuery\.of\(context\)\.padding\.top,\n                child: GestureDetector\(\n                  onTap: \(\) \{\n                    _searchFocusNode\.unfocus\(\);\n                    setState\(\(\) \{\n                      _mapSuggestions = \[\];\n                      _isSearchingAddress = false;\n                    \}\);\n                  \},\n                  behavior: HitTestBehavior\.opaque,\n                  child: Container\(color: Colors\.transparent\),\n                \),\n              \),\n\n            // ── Address Suggestions Overlay \(Map Mode only\) ──\n            if \(viewMode == ViewMode\.map &&\n                \(_isSearchingAddress \|\| _mapSuggestions\.isNotEmpty\)\)\n              Positioned\(\n                top: 88 \+ MediaQuery\.of\(context\)\.padding\.top,\n                left: 16,\n                right: 16,\n                child: _buildAddressSuggestionsOverlay\(\),\n              \),\n          \],\n        \),\n      \),\n    \);\n  \}', '', content) # Just wiping out the old duplicate if it existed, but it won't match exactly.

# A better way to clean the file: write it from scratch to be 100% sure!
# Wait, guest_home_screen.dart is huge. The rest of the file has _SearchHeader and _QuickFilterChip!
# I can just use a much simpler approach. Let me write out the exact build method.
