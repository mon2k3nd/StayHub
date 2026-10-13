import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix static access to instance member
content = content.replace('await OsmMapService.searchAddress(q)', 'await OsmMapService().searchSuggestions(q)')

# 2. Fix duplicate _onSearchChanged. I inserted the whole state class chunk, but I didn't delete the old ones properly.
# Let's find the start of the OLD state class and remove it.
# Wait, the duplicate _onSearchChanged is at line 479. The unused one is at line 155.
# Let's just remove the first 418 lines that I inserted!
# Ah, I see! I inserted class _GuestHomeScreenState ... but I DID NOT REPLACE the old one properly!
# I will use regex to find all class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen>
# Let's just output the whole file and fix it manually.
