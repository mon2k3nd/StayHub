extension StringExtensions on String {
  String get initials {
    if (trim().isEmpty) return '??';
    final parts = trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
