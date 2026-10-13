import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the top of build
build_target = '''  @override
  Widget build(BuildContext context) {
    
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);

    // Chi?u cao header co dan MU?T MA (khng nh?y c?ng 160 224).
    // - Ch? d? thu?ng: 3 t?ng (nav + search bar + d?i danh m?c 3D)  224.
    // - Ch? d? da l?c: thu g?n cn 2 t?ng (nav + search bar)  160.
    // AnimatedContainer bn du?i s? n?i suy gi tr? ny theo th?i gian nn
    // n?i dung khng bao gi? b? "gi?t" hay b? header che khu?t.
        final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    final _viewMode = ref.watch(guestViewModeProvider);
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;
    return Scaffold('''

clean_build_top = '''  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);
    
    final activeCategory = ref.watch(guestActiveCategoryProvider);
    final viewMode = ref.watch(guestViewModeProvider);
    final isFiltered = activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    return Scaffold('''

content = content.replace(build_target, clean_build_top)

# Fix the end of build
end_target = '''              ),
            ],
          ],
        ),
      ),
    );
  }'''

clean_end = '''              ),
            ],
        ),
    );
  }'''

content = content.replace(end_target, clean_end)

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
