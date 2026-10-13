import sys

with open('lib/features/guest/presentation/guest_home_screen_backup.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []

skip = False
for i, line in enumerate(lines):
    if "import 'package:flutter/material.dart';" in line:
        new_lines.append(line)
        new_lines.append("import '../application/guest_header_providers.dart';\n")
        continue
    
    if 'void _onSearchChanged(String v) {' in line:
        skip = True
        continue
    if skip and '/// Mở bộ lọc server-driven (Liquid Glass)' in line:
        skip = False
        new_lines.append(line)
        continue
    if skip:
        continue
        
    if '/// Định vị GPS' in line:
        skip = True
        continue
    if skip and 'void _onSearchChanged(' in line:
        skip = False
        new_lines.append(line)
        continue
    if skip:
        continue

    if 'await OsmMapService.searchAddress(q)' in line:
        new_lines.append(line.replace('await OsmMapService.searchAddress(q)', 'await OsmMapService().searchSuggestions(q)'))
        continue

    if line.strip() == '],':
        # Check if the previous lines were the end of Builder
        if i > 5 and 'Builder(' in lines[i-15]:
            pass
        # I'll just keep it for now and fix it manually if it fails
        
    new_lines.append(line)

with open('lib/features/guest/presentation/guest_home_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Done')
