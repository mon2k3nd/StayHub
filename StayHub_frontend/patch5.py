import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the build method top
build_start = content.find('  @override\n  Widget build(BuildContext context) {')
scaffold = content.find('    return Scaffold(', build_start)
if scaffold != -1:
    clean_build_top = '''  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);
    
    final activeCategory = ref.watch(guestActiveCategoryProvider);
    final viewMode = ref.watch(guestViewModeProvider);
    final isFiltered = activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;

'''
    content = content[:build_start] + clean_build_top + content[scaffold:]

# Fix variable names in the Scaffold
content = content.replace('canPop: _activeCategory == null,', 'canPop: !isFiltered,')
content = content.replace('activeCategory: _activeCategory,', 'activeCategory: activeCategory,')
content = content.replace('viewMode: _viewMode,', 'viewMode: viewMode,')
content = content.replace('_viewMode == ViewMode.map', 'viewMode == ViewMode.map')

# Fix the messy bracket at the end of build method
sug_idx = content.find('                child: _buildAddressSuggestionsOverlay(),\n              ),')
if sug_idx != -1:
    end_sug_idx = content.find('              ),', sug_idx) + 16
    next_method_idx = content.find('  // ── Thân trang List ──', end_sug_idx)
    if next_method_idx == -1:
        next_method_idx = content.find('  Widget _buildBody', end_sug_idx)
    
    clean_tail = '''
          ],
        ),
      ),
    );
  }

'''
    if next_method_idx != -1:
        content = content[:end_sug_idx] + clean_tail + content[next_method_idx:]

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
