import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make a copy for the Header
header_content = content
header_content = header_content.replace('class GuestHomeScreen', 'class SharedGuestHeader')
header_content = header_content.replace('GuestHomeScreenState', 'SharedGuestHeaderState')
header_content = header_content.replace('GuestHomeScreen>', 'SharedGuestHeader>')
header_content = header_content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/guest_header_providers.dart';")

# Apply provider replacements
header_content = header_content.replace('ViewMode _viewMode = ViewMode.list;', '')
header_content = header_content.replace('int? _activeCategory;', '')
header_content = header_content.replace('_viewMode == ViewMode.map', 'ref.read(guestViewModeProvider) == ViewMode.map')
header_content = header_content.replace('_viewMode == ViewMode.list', 'ref.read(guestViewModeProvider) == ViewMode.list')
header_content = header_content.replace('setState(() => _activeCategory = index);', 'ref.read(guestActiveCategoryProvider.notifier).state = index;')
header_content = header_content.replace('setState(() {\n      _activeCategory = null;', 'ref.read(guestActiveCategoryProvider.notifier).state = null;\n      setState(() {')
header_content = header_content.replace('final newMode = _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;', 'final current = ref.read(guestViewModeProvider);\n    final newMode = current == ViewMode.list ? ViewMode.map : ViewMode.list;\n    ref.read(guestViewModeProvider.notifier).state = newMode;')
header_content = header_content.replace('setState(() {\n      _viewMode = newMode;\n    });', '')

header_content = header_content.replace('_activeCategory != null', 'ref.watch(guestActiveCategoryProvider) != null')
header_content = header_content.replace('_activeCategory!', 'ref.read(guestActiveCategoryProvider)!')
header_content = header_content.replace('_activeCategory == index', 'ref.read(guestActiveCategoryProvider) == index')
header_content = header_content.replace('activeCategory: _activeCategory,', 'activeCategory: ref.watch(guestActiveCategoryProvider),')
header_content = header_content.replace('final isFiltered = ref.watch(guestActiveCategoryProvider) != null;\n    // Chiều cao header co dãn', 'final headerExtent = ref.watch(guestHeaderHeightProvider);\n    final isFiltered = headerExtent == 160.0;\n    // Chiều cao header co dãn')
header_content = re.sub(r'final headerExtent = isFiltered \? 160\.0 : 224\.0;\n', '', header_content)
header_content = header_content.replace('return PopScope(', 'final _viewMode = ref.watch(guestViewModeProvider);\n    return PopScope(')

# Extract just the Stack of the header for SharedGuestHeader
build_start = header_content.find('  @override\n  Widget build(BuildContext context) {')
pop_scope_start = header_content.find('    return PopScope(', build_start)
header_start_comment = header_content.find('            // ── The Floating Header (Liquid Glass) ──')
stack_end = header_content.find('          ],\n        ),\n      ),\n    );\n  }')

if pop_scope_start != -1 and header_start_comment != -1 and stack_end != -1:
    header_block = header_content[header_start_comment:stack_end]
    new_return = '''    return Stack(
      clipBehavior: Clip.none,
      children: [
''' + header_block + '''
      ],
    );
  }
'''
    header_content = header_content[:pop_scope_start] + new_return + header_content[stack_end+38:]

# Now, create GuestHomeBody
body_content = content
body_content = body_content.replace('class GuestHomeScreen', 'class GuestHomeBody')
body_content = body_content.replace('GuestHomeScreenState', 'GuestHomeBodyState')
body_content = body_content.replace('GuestHomeScreen>', 'GuestHomeBody>')
body_content = body_content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../application/guest_header_providers.dart';")

# Body doesn't need header state!
body_content = re.sub(r'  ViewMode _viewMode = ViewMode\.list;\n  int\? _activeCategory;\n\n  //.*?_mapSuggestions = \[\];\n  bool _isSearchingAddress = false;', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  final _searchCtrl = TextEditingController\(\);\n  final _searchFocusNode = FocusNode\(\);\n  Timer\? _debounce;\n  late final AnimationController _pulseCtrl;', '', body_content)
body_content = re.sub(r'  @override\n  void initState\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  @override\n  void dispose\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _onSearchChanged\(String q\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  Future<void> _handleMapAddressSearch\(String q\) async \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  Widget _buildAddressSuggestionsOverlay\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  Future<void> _openFilter\(\[String\? focusedSection\]\) async \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _openSearch\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _applyChip\(double max\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _selectCategory\(int index\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _resetCategory\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)
body_content = re.sub(r'  void _toggleView\(\) \{.*?\n  \}', '', body_content, flags=re.DOTALL)

# In body, read ViewMode from provider
build_start_body = body_content.find('  @override\n  Widget build(BuildContext context) {')
body_content = body_content[:build_start_body] + body_content[build_start_body:].replace('    final asyncState', '    final _viewMode = ref.watch(guestViewModeProvider);\n    final asyncState', 1)
body_content = body_content.replace('final isFiltered = _activeCategory != null;\n    // Chiều cao header co dãn', 'final headerExtent = ref.watch(guestHeaderHeightProvider);\n    final isFiltered = headerExtent == 160.0;\n    // Chiều cao header co dãn')
body_content = re.sub(r'final headerExtent = isFiltered \? 160\.0 : 224\.0;\n', '', body_content)

# Remove PopScope
body_content = re.sub(r'    return PopScope\(\n      canPop: !isFiltered,\n      onPopInvokedWithResult: \(didPop, _\) \{.*?\n      \},\n      child: Scaffold\(', '    return Scaffold(', body_content, flags=re.DOTALL)

# Remove the Header from Stack in Body
header_start_comment = body_content.find('            // ── The Floating Header (Liquid Glass) ──')
overlay_end_comment = body_content.find('            // ── Bắt sự kiện chạm ngoài')
if header_start_comment != -1 and overlay_end_comment != -1:
    # Find the end of the positioned block for the overlay
    next_positioned = body_content.find('          ],\n        ),\n', overlay_end_comment)
    body_content = body_content[:header_start_comment] + body_content[next_positioned:]

# Write to disk
with open('lib/features/guest/presentation/widgets/shared_guest_header.dart', 'w', encoding='utf-8') as f:
    f.write(header_content)

with open('lib/features/guest/presentation/guest_home_body.dart', 'w', encoding='utf-8') as f:
    f.write(body_content)

print('Success')
