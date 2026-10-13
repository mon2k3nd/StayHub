import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. We know guest_header_providers.dart is missing an import! Let's add it.
if "import '../../application/guest_header_providers.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/guest_header_providers.dart';")

# 2. We need to fix the duplicate _onSearchChanged! 
# Let's completely remove the one starting with oid _onSearchChanged(String q) that I injected, OR the one with (String v)!
# Since the one I injected uses q and oomSearchProvider, I will keep it. The one using  is older.
# Actually, let's just write a script to replace the entire uild method and the _GuestHomeScreenState carefully using python ast or just regex.

# Since I know the exact lines, let's just fix the exact lines!
# error 1: duplicate _onSearchChanged. Let's find oid _onSearchChanged(String v) and remove it.
start_v = content.find('  void _onSearchChanged(String v) {')
if start_v != -1:
    end_v = content.find('  /// Mở bộ lọc server-driven', start_v)
    content = content[:start_v] + content[end_v:]

# error 2: _getUserCurrentLocationAndSelect isn't referenced
# Let's remove it.
start_gps = content.find('  /// Định vị GPS')
if start_gps != -1:
    end_gps = content.find('  void _selectAddressSuggestion(OsmSuggestion item)', start_gps)
    if end_gps != -1:
        content = content[:start_gps] + content[end_gps:]

# error 3: _selectAddressSuggestion isn't referenced
start_sug = content.find('  void _selectAddressSuggestion(OsmSuggestion item)')
if start_sug != -1:
    end_sug = content.find('  void _onSearchChanged(', start_sug)
    if end_sug != -1:
        content = content[:start_sug] + content[end_sug:]

# error 4: headerExtent is undefined in build method
# We need to define headerExtent and fix the duplicated 	opPadding.
# Let's search for the uild method
build_start = content.find('  @override\n  Widget build(BuildContext context) {')
build_end = content.find('        backgroundColor: AppTheme.kBackgroundLight,', build_start)

# Replace the top of the build method
clean_build_top = '''  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);
    
    final activeCategory = ref.watch(guestActiveCategoryProvider);
    final viewMode = ref.watch(guestViewModeProvider);
    final isFiltered = activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    return Scaffold(
'''
content = content[:build_start] + clean_build_top + content[build_end:]

# error 5: Undefined name '_activeCategory' in _buildBody or something?
# I saw ctiveCategory: _activeCategory somewhere. Let's fix it!
content = content.replace('activeCategory: _activeCategory,', 'activeCategory: activeCategory,')

# error 6: missing braces or semicolons at line 694. 
# This might be in the Scaffold children or something?
# Let's look for ); or something missing.
# Wait, let's just write to file and check!

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
