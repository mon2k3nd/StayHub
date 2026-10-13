import re

with open('lib/features/guest/presentation/guest_main_scaffold.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'widgets/global_guest_header.dart';", "")
header_str = '''
            // The Persistent Global Header
            const Positioned(
              top: 0, left: 0, right: 0,
              child: GlobalGuestHeader(),
            ),
'''
content = content.replace(header_str, "")

with open('lib/features/guest/presentation/guest_main_scaffold.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Success')
