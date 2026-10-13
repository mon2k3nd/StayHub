import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Using regex to replace the old _openFilter
pattern = re.compile(r'  Future<void> _openFilter\(\[String\? focusedSection\]\) async \{.*?\}', re.DOTALL)

new_open_filter = '''  OverlayEntry? _overlayEntry;

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openFilter(String? focusedSection, Offset? pos, Size? size) async {
    if (focusedSection == 'Khu v?c' && pos != null && size != null) {
      if (_overlayEntry != null) {
        _closeOverlay();
        return;
      }
      
      final cur = ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
      
      _overlayEntry = OverlayEntry(
        builder: (ctx) => AddressDropdownOverlay(
          position: pos,
          size: size,
          initialProvince: cur.province,
          initialDistrict: cur.district,
          initialWard: cur.ward,
          onApply: (p, d, w) {
            _closeOverlay();
            final curFilter = ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
            final newFilter = curFilter.copyWith(
              province: p,
              district: d,
              ward: w,
              clearProvince: p == null,
              clearDistrict: d == null,
              clearWard: w == null,
            );
            ref.read(roomSearchProvider.notifier).applyFilter(newFilter);
          },
          onDismiss: _closeOverlay,
        ),
      );
      
      Overlay.of(context).insert(_overlayEntry!);
      return;
    }
    
    // Normal bottom sheet filter
    final cur = ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    final profile = _activeCategory != null
        ? RoomFilterProfile.forRoomType(_kCategories[_activeCategory!].roomType)
        : RoomFilterProfile.all;

    final res = await RoomSearchFilterSheet.show(
      context,
      initial: cur,
      profile: profile,
      focusedSection: focusedSection,
    );
    if (res != null && mounted) {
      ref.read(roomSearchProvider.notifier).applyFilter(res);
    }
  }'''

content = pattern.sub(new_open_filter, content)

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Regex Replace Success')
