with open('lib/features/guest/presentation/guest_home_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i in range(605, 625):
        if i < len(lines):
            print(f"{i+1}: {lines[i].rstrip()}")
