import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the ENTIRE build method with a perfectly formatted version
build_start = content.find('  @override\n  Widget build(BuildContext context) {')
build_end = content.find('  Widget _buildBody(', build_start)
if build_end == -1:
    build_end = content.find('  // ── Thân trang List ──', build_start)

if build_start != -1 and build_end != -1:
    clean_build = '''  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);
    
    final activeCategory = ref.watch(guestActiveCategoryProvider);
    final viewMode = ref.watch(guestViewModeProvider);
    final isFiltered = activeCategory != null;
    final headerExtent = isFiltered ? 160.0 : 224.0;
    final topPadding = MediaQuery.of(context).padding.top + headerExtent;

    return Scaffold(
        backgroundColor: AppTheme.kBackgroundLight,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Nền trang ──
            Positioned.fill(
              child: Image.asset(
                'assets/images/hero_city_white.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),

            // ── Nội dung (Map / List) ──
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
                child: viewMode == ViewMode.map
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
          ],
        ),
    );
  }

'''
    content = content[:build_start] + clean_build + content[build_end:]

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
