import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''        final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    final _viewMode = ref.watch(guestViewModeProvider);
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;
    return Scaffold('''

replacement = '''    final _activeCategory = ref.watch(guestActiveCategoryProvider);
    final isFiltered = _activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    final _viewMode = ref.watch(guestViewModeProvider);
    return Scaffold('''

content = content.replace(target, replacement)

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
