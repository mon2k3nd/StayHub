// No external package needed - Vietnamese diacritics handled inline.

class AddressMappingService {
  // ---------------------------------------------------------------------------
  // Diacritic removal (Vietnamese + Latin extended)
  // ---------------------------------------------------------------------------
  static const String _withDia =
      'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ'
      'ÁÀẢẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ'
      'ÁÀẢẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
  static const String _withoutDia =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

  static String _unAccent(String str) {
    for (int i = 0; i < _withDia.length; i++) {
      str = str.replaceAll(_withDia[i], _withoutDia[i]);
    }
    return str;
  }

  // ---------------------------------------------------------------------------
  // String Normalization Pipeline
  // Produces a lowercase, accent-free, prefix-free, whitespace-free key —
  // identical to _cleanName() in create_branch_screen.dart.
  // ---------------------------------------------------------------------------
  static String normalizeString(String input) {
    if (input.isEmpty) return '';
    String s = _unAccent(input).toLowerCase();
    s = s
        .replaceAll(RegExp(r'\bthanh pho\b'), '')
        .replaceAll(RegExp(r'\btinh\b'), '')
        .replaceAll(RegExp(r'\bquan\b'), '')
        .replaceAll(RegExp(r'\bhuyen\b'), '')
        .replaceAll(RegExp(r'\bthi xa\b'), '')
        .replaceAll(RegExp(r'\bphuong\b'), '')
        .replaceAll(RegExp(r'\bthi tran\b'), '')
        .replaceAll(RegExp(r'\bxa\b'), '')
        .replaceAll(RegExp(r'\bcity\b'), '')
        .replaceAll(RegExp(r'\bdistrict\b'), '')
        .replaceAll(RegExp(r'\bward\b'), '')
        .replaceAll(RegExp(r'\bprovince\b'), '')
        .replaceAll(RegExp(r'\btown\b'), '')
        .replaceAll(RegExp(r'\bmunicipality\b'), '');
    // Remove ALL whitespace so "ha noi" == "hanoi"
    return s.replaceAll(RegExp(r'\s+'), '').trim();
  }

  // ---------------------------------------------------------------------------
  // Alias Dictionary  (keys are already normalized / space-free)
  // ---------------------------------------------------------------------------
  static const Map<String, String> provinceAliases = {
    // Ho Chi Minh
    'hcm': '79',
    'saigon': '79',
    'sg': '79',
    'hochiminh': '79',
    'tphcm': '79',
    // Ha Noi
    'hn': '01',
    'hanoi': '01',
    'thucdohanoi': '01',
    // Ba Ria – Vung Tau
    'brvt': '77',
    'vungtau': '77',
    'baria': '77',
    'bariavungtau': '77',
    // City names often used instead of province names
    'halong': '22', // Quang Ninh
    'vinh': '40', // Nghe An
    'dalat': '68', // Lam Dong
    'hue': '46', // Thua Thien – Hue
    'buonmathuot': '66', // Dak Lak
    'nhatrang': '56', // Khanh Hoa
    'phanthiet': '60', // Binh Thuan
    'bienhoa': '75', // Dong Nai
    'thudaumot': '74', // Binh Duong
    'cantho': '92',
    'danang': '48',
    'haiphong': '31',
  };

  /// Multi-tier Lookup for Esgoo Province Map
  static Map<String, dynamic>? findEsgooProvince(
    String rawAddress,
    List<dynamic> provinces63,
  ) {
    final cleanInput = normalizeString(rawAddress);
    if (cleanInput.isEmpty) return null;

    // Tier 1: Exact Match (after normalization)
    for (final p in provinces63) {
      final cleanProvinceName = normalizeString(
        p['full_name'] ?? p['name'] ?? '',
      );
      if (cleanProvinceName == cleanInput) {
        return p as Map<String, dynamic>;
      }
    }

    // Tier 2: Alias Match
    if (provinceAliases.containsKey(cleanInput)) {
      final esgooId = provinceAliases[cleanInput];
      try {
        return provinces63.firstWhere((p) => p['id'] == esgooId)
            as Map<String, dynamic>;
      } catch (_) {}
    }

    // Tier 3: Fuzzy / Contains Match
    for (final p in provinces63) {
      final cleanProvinceName = normalizeString(
        p['full_name'] ?? p['name'] ?? '',
      );
      // If the input contains the province name, or province name contains input (and input is reasonably long)
      if (cleanProvinceName.isNotEmpty && cleanInput.isNotEmpty) {
        if (cleanInput.contains(cleanProvinceName) ||
            (cleanProvinceName.contains(cleanInput) && cleanInput.length > 3)) {
          return p as Map<String, dynamic>;
        }
      }
    }

    return null;
  }

  /// Generic multi-tier Lookup for District and Ward
  static Map<String, dynamic>? findBestMatch(
    String rawAddress,
    List<dynamic> list, {
    String? fallbackAddress,
  }) {
    final cleanInput = normalizeString(rawAddress);

    if (cleanInput.isNotEmpty) {
      // Tier 1: Exact Match (after normalization)
      for (final item in list) {
        final cleanName = normalizeString(
          item['full_name'] ?? item['name'] ?? '',
        );
        if (cleanName == cleanInput) {
          return item as Map<String, dynamic>;
        }
      }

      // Tier 2: Fuzzy / Contains Match
      for (final item in list) {
        final cleanName = normalizeString(
          item['full_name'] ?? item['name'] ?? '',
        );
        if (cleanName.isNotEmpty) {
          if (cleanInput.contains(cleanName) ||
              (cleanName.contains(cleanInput) && cleanInput.length > 3)) {
            return item as Map<String, dynamic>;
          }
        }
      }
    }

    // Tier 3: Strong Fallback
    final cleanFallback = fallbackAddress != null
        ? normalizeString(fallbackAddress)
        : '';
    if (cleanFallback.isNotEmpty) {
      for (final item in list) {
        final cleanName = normalizeString(
          item['full_name'] ?? item['name'] ?? '',
        );
        if (cleanName.isNotEmpty &&
            (cleanName.length > 2 || int.tryParse(cleanName) != null) &&
            cleanFallback.contains(cleanName)) {
          return item as Map<String, dynamic>;
        }
      }
    }

    return null;
  }
}
