import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../../application/guest_header_providers.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/guest_header_providers.dart';")

start_v = content.find('  void _onSearchChanged(String v) {')
if start_v != -1:
    end_v = content.find('  /// Mở bộ lọc server-driven', start_v)
    content = content[:start_v] + content[end_v:]

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

build_start = content.find('  @override\n  Widget build(BuildContext context) {')
build_end = content.find('        backgroundColor: AppTheme.kBackgroundLight,', build_start)

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

content = content.replace('activeCategory: _activeCategory,', 'activeCategory: activeCategory,')

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
