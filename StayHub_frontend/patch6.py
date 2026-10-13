import re

with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix iewMode being used before declaration in initState, _onSearchChanged, _openSearch
content = content.replace('if (viewMode == ViewMode.map', 'if (ref.read(guestViewModeProvider) == ViewMode.map')

# Fix unused _selectAddressSuggestion
start_sug = content.find('  void _selectAddressSuggestion(OsmSuggestion item)')
if start_sug != -1:
    end_sug = content.find('  void _onSearchChanged(', start_sug)
    if end_sug != -1:
        content = content[:start_sug] + content[end_sug:]

# Fix the messy brackets at the end of build method (around line 614)
# We know the correct ending is:
#           ],
#         ),
#       ),
#     );
#   }
# Let's search for _buildAddressSuggestionsOverlay() in uild() and overwrite the rest of uild()
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
