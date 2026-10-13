import re

with open('lib/features/guest/presentation/guest_home_screen_backup.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Add import
if "import '../../application/guest_header_providers.dart';" not in content and "import '../application/guest_header_providers.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../application/guest_header_providers.dart';")

# Fix 2: Remove duplicate _onSearchChanged (the one with String v)
start_v = content.find('  void _onSearchChanged(String v) {')
if start_v != -1:
    end_v = content.find('  /// Mở bộ lọc server-driven', start_v)
    content = content[:start_v] + content[end_v:]

# Fix 3: Fix static method call
content = content.replace('await OsmMapService.searchAddress(q)', 'await OsmMapService().searchSuggestions(q)')

# Fix 4: Fix unused methods
start_gps = content.find('  /// Định vị GPS')
if start_gps != -1:
    end_gps = content.find('  void _selectAddressSuggestion(OsmSuggestion item)', start_gps)
    if end_gps != -1:
        content = content[:start_gps] + content[end_gps:]

start_sug = content.find('  void _selectAddressSuggestion(OsmSuggestion item)')
if start_sug != -1:
    end_sug = content.find('  void _onSearchChanged(', start_sug)
    if end_sug != -1:
        content = content[:start_sug] + content[end_sug:]

# Fix 5: The messy bracket at the end of build method (around line 694 in backup)
# Let's find _buildAddressSuggestionsOverlay(),
sug_idx = content.find('                child: _buildAddressSuggestionsOverlay(),\n              ),')
if sug_idx != -1:
    end_sug_idx = content.find('              ),', sug_idx) + 16
    # Right after this, it should just be:
    #           ],
    #         ),
    #       ),
    #     );
    #   }
    
    # We will replace whatever junk is there until the next method (which is probably _buildBody)
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


# Fix 6: Undefined variable guestViewModeProvider in _GuestHomeScreenState.build
# It was caused by inal _viewMode = ref.watch(guestViewModeProvider); being inserted twice or incorrectly.
# Let's replace the top of the build method carefully.
build_start = content.find('  @override\n  Widget build(BuildContext context) {')
pop_scope = content.find('    return PopScope(', build_start)
if pop_scope != -1:
    # Replace from build_start to pop_scope
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
    content = content[:build_start] + clean_build_top + content[pop_scope:]

# Also, change canPop: !isFiltered if it's not using the right variable
content = content.replace('canPop: _activeCategory == null,', 'canPop: !isFiltered,')
content = content.replace('activeCategory: _activeCategory,', 'activeCategory: activeCategory,')
content = content.replace('viewMode: _viewMode,', 'viewMode: viewMode,')
content = content.replace('_viewMode == ViewMode.map', 'viewMode == ViewMode.map')

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
